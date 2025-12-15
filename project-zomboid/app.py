from flask import Flask, request, redirect, render_template_string, Response
import subprocess, os

app = Flask(__name__)

USER = os.getenv("PZ_USER", "admin")
PASS = os.getenv("PZ_PASS", "changeme")

def auth():
    return Response("Authentication required", 401,
        {"WWW-Authenticate": "Basic realm='Zomboid'"})

@app.before_request
def check_auth():
    a = request.authorization
    if not a or a.username != USER or a.password != PASS:
        return auth()

PAGE = """
<h2>Project Zomboid Server</h2>
<a href="/start">Start</a> |
<a href="/stop">Stop</a> |
<a href="/restart">Restart</a> |
<a href="/update">Update</a> |
<a href="/logs">Logs</a>
<hr>
{{ content }}
"""

@app.route("/")
def index():
    return render_template_string(PAGE, content="")

@app.route("/start")
def start():
    subprocess.run(["systemctl", "start", "zomboid"])
    return redirect("/")

@app.route("/stop")
def stop():
    subprocess.run(["systemctl", "stop", "zomboid"])
    return redirect("/")

@app.route("/restart")
def restart():
    subprocess.run(["systemctl", "restart", "zomboid"])
    return redirect("/")

@app.route("/update")
def update():
    subprocess.run(["steamcmd", "+runscript", "/home/pzserver/update_zomboid.txt"])
    return redirect("/")

@app.route("/logs")
def logs():
    out = subprocess.check_output(
        ["journalctl", "-u", "zomboid", "-n", "50"],
        text=True
    )
    return render_template_string(PAGE, content=f"<pre>{out}</pre>")

app.run(host="0.0.0.0", port=9000)
