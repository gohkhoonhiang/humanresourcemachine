import tornado.ioloop
import tornado.web
from settings import settings
from tornado.options import options
from urls import url_patterns


def make_app():
    return tornado.web.Application(url_patterns, **settings)


if __name__ == '__main__':
    app = make_app()
    app.listen(options.port)
    tornado.ioloop.IOLoop.current().start()


