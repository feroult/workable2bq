import fitz
import requests


def load_resume_from_url(id, url):
    r = requests.get(url)
    filename = f'/export_resumes_pdfs/{id}.pdf'
    with open(filename, 'wb') as f:
        f.write(r.content)
    return load_resume_from_file(filename)


def load_resume_from_file(filename):
    with fitz.open(filename) as doc:
        text = ""
        for page in doc:
            text += page.getText()
    return text


if __name__ == '__main__':
    load_resume_from_file("/app/x.pdf")
