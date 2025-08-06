from flask import Flask, jsonify
from config import SQLALCHEMY_DATABASE_URI
from models import db, User

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = SQLALCHEMY_DATABASE_URI
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)


@app.route("/")
def hello():
    return jsonify(message="Flask + Cloud SQL API")

@app.route("/users")
def users():
    users = User.query.all()
    return jsonify([{"id": u.id, "name": u.name} for u in users])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
