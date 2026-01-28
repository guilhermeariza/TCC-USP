use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{BufReader, BufWriter};
use std::path::{Path, PathBuf};
use serde::{Serialize, Deserialize};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Serialize, Deserialize, Clone)]
enum LogValue<V> {
    Value(V),
    Tombstone,
}

pub struct LSMTree<K, V> {
    memtable: BTreeMap<K, LogValue<V>>,
    threshold: usize,
    data_dir: PathBuf,
}

impl<K, V> LSMTree<K, V> 
where K: Ord + Clone + Serialize + for<'de> Deserialize<'de>,
      V: Clone + Serialize + for<'de> Deserialize<'de> 
{
    pub fn new(threshold: usize, data_dir: &str) -> Self {
        let path = PathBuf::from(data_dir);
        if !path.exists() {
            fs::create_dir_all(&path).unwrap();
        }
        
        LSMTree {
            memtable: BTreeMap::new(),
            threshold,
            data_dir: path,
        }
    }

    pub fn insert(&mut self, key: K, value: V) {
        self.memtable.insert(key, LogValue::Value(value));
        
        if self.memtable.len() >= self.threshold {
            self.flush();
        }
    }
    
    pub fn delete(&mut self, key: K) {
        self.memtable.insert(key, LogValue::Tombstone);
         if self.memtable.len() >= self.threshold {
            self.flush();
        }
    }

    fn flush(&mut self) {
        if self.memtable.is_empty() {
            return;
        }

        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_micros();
        
        let filename = format!("sst_{}.json", timestamp);
        let path = self.data_dir.join(filename);
        
        let file = File::create(&path).expect("Failed to create SSTable file");
        let writer = BufWriter::new(file);
        
        serde_json::to_writer(writer, &self.memtable).expect("Failed to write SSTable");
        
        self.memtable.clear();
    }

    pub fn search(&self, key: &K) -> Option<V> {
        // 1. Check MemTable
        if let Some(val) = self.memtable.get(key) {
            return match val {
                LogValue::Value(v) => Some(v.clone()),
                LogValue::Tombstone => None,
            };
        }

        // 2. Check SSTables (latest to newest)
        // In a real implementation we would cache file handles or metadata.
        // Here we list dir every time (slow, but works for "simple" demonstration).
        
        let mut entries: Vec<_> = fs::read_dir(&self.data_dir)
            .unwrap()
            .filter_map(|res| res.ok())
            .map(|entry| entry.path())
            .filter(|path| path.extension().map_or(false, |ext| ext == "json"))
            .collect();

        // Sort reverse alphabetically (assuming timestamp in name ensures order)
        // sst_123, sst_124. Reverse: sst_124, sst_123.
        entries.sort_by(|a, b| b.cmp(a));

        for path in entries {
            let file = File::open(&path).ok()?;
            let reader = BufReader::new(file);
            
            // Streaming search is hard with JSON unless we parse standard format.
            // Loading whole map is easiest for "simple" impl.
            let map: BTreeMap<K, LogValue<V>> = serde_json::from_reader(reader).ok()?;
            
            if let Some(val) = map.get(key) {
                 return match val {
                    LogValue::Value(v) => Some(v.clone()),
                    LogValue::Tombstone => None,
                };
            }
        }

        None
    }
    
    // Simple compaction: Load all, merge, write one big file? 
    // Or merge to Level 1? 
    // Let's do a meaningful compaction: Merge all SSTables into a NEW set of SSTables? 
    // Or just merge EVERYTHING into one big SSTable (Level 0 -> Level 1).
    pub fn compact(&mut self) {
         // Load all SSTables
        let mut merged_map: BTreeMap<K, LogValue<V>> = BTreeMap::new();
        
        let paths: Vec<_> = fs::read_dir(&self.data_dir)
            .unwrap()
            .filter_map(|res| res.ok())
            .map(|entry| entry.path())
            .filter(|path| path.extension().map_or(false, |ext| ext == "json"))
            .collect(); // Don't sort yet, we need to apply in order of creation (Oldest first) to overwrite correctly?
            
        // Correct merge order: 
        // Start with oldest file. Insert entries. 
        // Then newer file. Overwrite entries. 
        // Final state reflects latest updates.
        
        // So Sort Ascending.
        let mut sorted_paths = paths.clone();
        sorted_paths.sort(); // sst_1... sst_2...
        
        for path in &sorted_paths {
            let file = File::open(path).expect("Failed to open SST");
            let reader = BufReader::new(file);
            let map: BTreeMap<K, LogValue<V>> = serde_json::from_reader(reader).expect("Failed to parse SST");
            
            for (k, v) in map {
                merged_map.insert(k, v);
            }
        }
        
        // Filter out tombstones?
        // In full compaction, if we have all history, we can safely drop Tombstones unless they cover keys in OLDER levels (Level > 1).
        // Here we only have Level 0 -> Level 1. So if we compacted everything, we can drop Tombstones.
        // But for safety, keep them? No, if we merged ALL files, and MemTable is separate? 
        // Wait, MemTable is not included in compact here.
        // So tombstones in compacted file must remain to hide potential keys in... wait, if we merge ALL files, there are no older files.
        // So we can drop Tombstones!
        // Unless, we consider MemTable might have older keys? No, MemTable is newer.
        // So yes, drop Tombstones.
        
        let final_map: BTreeMap<K, LogValue<V>> = merged_map.into_iter()
            .filter(|(_, v)| matches!(v, LogValue::Value(_)))
            .collect();
        
        // Now delete old files
        for path in paths {
            fs::remove_file(path).unwrap();
        }
        
        // Write new big file
         let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_micros();
        let filename = format!("sst_{}_compacted.json", timestamp);
        let path = self.data_dir.join(filename);
        
        let file = File::create(&path).unwrap();
        let writer = BufWriter::new(file);
        serde_json::to_writer(writer, &final_map).unwrap();
    }
}
