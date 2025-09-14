from fastapi import FastAPI, UploadFile, File, Form
import boto3
import os
from dotenv import load_dotenv
import fitz  # PyMuPDF for PDFs
import docx

# Load environment variables
load_dotenv()

app = FastAPI()

# Initialize Polly client
polly_client = boto3.client(
    "polly",
    region_name=os.getenv("AWS_REGION"),
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
)

# Extract text from PDF
def extract_text_from_pdf(file_path):
    doc = fitz.open(file_path)
    text = ""
    for page in doc:
        text += page.get_text()
    return text

# Extract text from DOCX
def extract_text_from_docx(file_path):
    doc = docx.Document(file_path)
    return "\n".join([para.text for para in doc.paragraphs])

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    # Save file temporarily
    file_location = f"temp_{file.filename}"
    with open(file_location, "wb") as f:
        f.write(await file.read())

    # Detect file type
    if file.filename.endswith(".pdf"):
        text = extract_text_from_pdf(file_location)
    elif file.filename.endswith(".docx"):
        text = extract_text_from_docx(file_location)
    elif file.filename.endswith(".txt"):
        with open(file_location, "r", encoding="utf-8") as f:
            text = f.read()
    else:
        return {"error": "Unsupported file type"}

    os.remove(file_location)  # cleanup
    return {"extracted_text": text[:500]}  # return preview

@app.post("/speak")
async def speak(text: str = Form(...)):
    response = polly_client.synthesize_speech(
        Text=text,
        OutputFormat="mp3",
        VoiceId="Joanna"  # You can change this to Matthew, Amy, etc.
    )
    audio_file = "output.mp3"
    with open(audio_file, "wb") as f:
        f.write(response["AudioStream"].read())
    return {"message": "Speech generated", "file": audio_file}
