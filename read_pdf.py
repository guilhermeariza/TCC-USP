try:
    import pypdf
    reader = pypdf.PdfReader("Template Resultados Preliminares_PT.pdf")
    for page in reader.pages:
        print(page.extract_text())
except ImportError:
    print("pypdf not installed")
    try:
        import PyPDF2
        reader = PyPDF2.PdfReader("Template Resultados Preliminares_PT.pdf")
        for page in reader.pages:
            print(page.extract_text())
    except ImportError:
        print("PyPDF2 not installed either")
