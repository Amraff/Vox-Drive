from docx import Document
import fitz  # PyMuPDF

def extract_text_from_file(file, filename):
    if filename.endswith(".txt"):
        return file.read().decode("utf-8")
    elif filename.endswith(".docx"):
        doc = Document(file)
        return " ".join([p.text for p in doc.paragraphs])
    elif filename.endswith(".pdf"):
        text = ""
        pdf = fitz.open(stream=file.read(), filetype="pdf")
        for page in pdf:
            text += page.get_text()
        return text
    else:
        raise ValueError("Unsupported file format")
