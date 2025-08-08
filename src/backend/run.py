from flask import Flask, jsonify, request
from config import SQLALCHEMY_DATABASE_URI, SQLALCHEMY_ENGINE_OPTIONS
from models import db, Order
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = SQLALCHEMY_DATABASE_URI
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = SQLALCHEMY_ENGINE_OPTIONS
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

@app.route("/")
def hello():
    return jsonify(message="Flask + Cloud SQL OK")

@app.route("/order", methods=["GET"])
def order():
    orders = Order.query.all()
    return jsonify([{'id': o.id, 'name': o.name} for o in orders])

@app.route("/order", methods=["POST"])
def create_order():
    data = request.get_json()
    new_order = Order(name=data['name'])
    db.session.add(new_order)
    db.session.commit()
    return jsonify(id=new_order.id, name=new_order.name), 201

if __name__ == "__main__":
    with app.app_context():
        try:
            # Manually create the tables if they don't exist
            db.create_all()
            print("DB Created")
        except Exception as e:
            print(f"DB Create Failed: {e}")

    debug_mode = os.environ.get('FLASK_DEBUG', 'false').lower() == 'true'
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=debug_mode)
