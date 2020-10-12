import fitz
import textract
import requests


def load_resume_from_url(id, ext, url):
    r = requests.get(url)
    filename = f'/export_resumes_binary/{id}.{ext}'
    with open(filename, 'wb') as f:
        f.write(r.content)
    return load_resume_from_file(filename)


def load_resume_from_file(filename):
    if '.pdf' in filename:
        return load_resume_from_pdf(filename)
    elif '.docx' in filename or '.doc' in filename:
        return load_resume_from_docx(filename)


def load_resume_from_pdf(filename):
    with fitz.open(filename) as doc:
        text = ""
        for page in doc:
            text += page.getText()
    return text


def load_resume_from_docx(filename):
    return textract.process(filename).decode("utf-8")


if __name__ == '__main__':
    print(load_resume_from_docx("/app/y.doc"))
