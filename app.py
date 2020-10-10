import os
import subprocess

from flask import Flask

app = Flask(__name__)


@app.route('/views')
def views():
    subprocess.run(["/app/bin/export-views.sh"])
    return 'ok'


@app.route('/candidates')
def candidates():
    subprocess.run(["/app/bin/export-candidates.sh"])
    return 'ok'


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
