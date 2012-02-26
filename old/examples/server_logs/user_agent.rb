

# For later, if we want to parse user agents:
#   http://code.google.com/p/browserscope/source/browse/trunk/models/user_agent.py
#   http://www.useragentstring.com/pages/All/
#   http://github.com/jaxn/parse-user-agent
#   http://code.google.com/p/browserscope/wiki/UserAgentParsing
#   http://code.google.com/p/ua-parser/source/browse/
#   http://github.com/shenoudab/active_device/tree/master/lib/active_device/


#
# * Mozilla based
# * Mozilla version
# * X11 based
# * Security
# * OS
# * CPU family
# * Language Tag
# * Renderer (i.e. Webkit, Trident, Presto)
# * Renderer Version
# * I don't see a utility for the "KHTML" and "like Gecko" bits, but whatever.
# * Based on
# * Browser Build (not really sure about this either)

# * Browser Family (i.e. Firefox, IE, Chrome, etc..)
# * Project Name (optional, i.e. Namoroka, Shiretoko)
# * Major Version
# * Minor Version
# * Version Third Bit
# * Version Fourth Bit
# * Open Question: How should we handle the "alpha/beta" bit, like apre1? I'm inclined to say we put it in its own datapoint and let people group together how ever they want, but not leave it attached to any of the version bits.

# Bot
# Brand
# Browser
# Engine
# Handset
# Model
# OS
