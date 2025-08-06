from flask import Flask, jsonify
from config import SQLALCHEMY_DATABASE_URI
from models import db, Order
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = SQLALCHEMY_DATABASE_URI
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

@app.route("/")
def hello():
    return jsonify(message="Flask + Cloud SQL API")

@app.route("/order")
def order():
    orders = Order.query.all()
    return jsonify([{"id": o.id, "name": o.name} for o in orders])

if __name__ == "__main__":
    with app.app_context():
        try:
            db.create_all()
            print('DB Created')
        except Exception as e:
            print(f'DB create failed: {e}')

    debug_mode = os.environ.get('FLASK_DEBUG', 'false').lower() == 'true'
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=debug_mode)
