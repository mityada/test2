import httplib
c = httplib.HTTPSConnection("webdav.yandex.ru")
c.request("GET", "/")
response = c.getresponse()
print response.status, response.reason
data = response.read()
print data
