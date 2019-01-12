from tornado.web import url
from handlers.main import MainHandler, PyInterpreterHandler


url_patterns = [
    url(r"/", MainHandler),
    url(r"/interpreter.html", PyInterpreterHandler),
]
