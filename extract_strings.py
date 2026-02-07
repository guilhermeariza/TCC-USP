import re

with open("Template Resultados Preliminares_PT.pdf", "rb") as f:
    data = f.read()

# Extract strings of length > 5
strings = re.findall(b"[A-Za-z0-9 \n\r\t-]{5,}", data)
for s in strings:
    try:
        print(s.decode('utf-8'))
    except:
        pass
