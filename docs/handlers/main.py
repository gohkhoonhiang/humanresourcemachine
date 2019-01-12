import tornado.web


class MainHandler(tornado.web.RequestHandler):
    def initialize(self):
        pass

    def get(self):
        self.render("index.html")


class PyInterpreterHandler(tornado.web.RequestHandler):
    def initialize(self):
        pass

    def get(self):
        self.render("interpreter.html")


