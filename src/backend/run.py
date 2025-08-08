from flask import Flask, jsonify, request
from config import SQLALCHEMY_DATABASE_URI, SQLALCHEMY_ENGINE_OPTIONS
from models import db, Order
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = SQLALCHEMY_DATABASE_URI
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = SQLALCHEMY_ENGINE_OPTIONS
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)


_HAS_CONNECTOR = False
try:
    from config import connector  # type: ignore
    _HAS_CONNECTOR = True
except ImportError:
    _HAS_CONNECTOR = False

if _HAS_CONNECTOR:
    @app.teardown_appcontext
    def close_connector(_exc):
        try:
            connector.close()
        except Exception:
            pass


@app.route('/')
def hello():
    return '<h1>Happy Testing :)</h1>"'


@app.route('/get_order', methods=['GET'])
def get_order():
    orders = Order.query.all()
    return jsonify([{"id": o.id, "name": o.name} for o in orders])


@app.route('/create_order', methods=['POST'])
def create_order():
    data = request.get_json(force=True) or {}
    name = data.get('name')
    if not name:
        return jsonify(error='`name` is required'), 400
    new_order = Order(name=name)
    db.session.add(new_order)
    db.session.commit()
    return jsonify(id=new_order.id, name=new_order.name), 201


def _init_db():
    with app.app_context():
        try:
            db.create_all()
            print('DB Created')
        except Exception as e:
            print(f'DB Create Failed: {e}')


if __name__ == '__main__':
    _init_db()
    debug_mode = os.getenv('FLASK_DEBUG', 'false').lower() == 'true'
    port = int(os.getenv('PORT', '5000'))
    app.run(host='0.0.0.0', port=port, debug=debug_mode)
