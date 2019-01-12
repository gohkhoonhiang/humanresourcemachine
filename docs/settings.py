import os
import tornado
from tornado.options import define, options, parse_config_file 


# Define file paths
ROOT = os.path.join(os.path.dirname(__file__))
STATIC_ROOT = os.path.join(ROOT, "static")
TEMPLATE_ROOT = os.path.join(ROOT, "templates")


# Define global options
define("port", default=9280, help="server port", type=int)
define("debug", default=True, help="debug mode")


# Define application settings
settings = {}
settings['debug'] = options.debug
settings['static_path'] = STATIC_ROOT
settings['template_path'] = TEMPLATE_ROOT


