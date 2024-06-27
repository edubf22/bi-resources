# Example in Python 3.5 to demonstrate how to use the Sage Intacct XML API
from xml.dom.minidom import Document
from XMLRequestClient import XMLRequestClient

# Provide values for these variables for testing purposes. Never store
# these in your application source code.
senderId = "myWebSenderId"
senderPassword = "myWebPassword"
sessionId = "mySessionId"

try:
    # Write the XML request with the minidom  module
    newdoc = Document();
    request = newdoc.createElement('request')
    newdoc.appendChild(request)
    control = newdoc.createElement('control')
    request.appendChild(control)
    senderid = newdoc.createElement('senderid')
    control.appendChild(senderid).appendChild(newdoc.createTextNode(senderId))
    senderpassword = newdoc.createElement('password')
    control.appendChild(senderpassword).appendChild(newdoc.createTextNode(senderPassword))
    controlid = newdoc.createElement('controlid')
    control.appendChild(controlid).appendChild(newdoc.createTextNode("testRequestId"))
    uniqueid = newdoc.createElement('uniqueid')
    control.appendChild(uniqueid).appendChild(newdoc.createTextNode("false"))
    dtdversion = newdoc.createElement('dtdversion')
    control.appendChild(dtdversion).appendChild(newdoc.createTextNode("3.0"))
    includewhitespace = newdoc.createElement('includewhitespace')
    control.appendChild(includewhitespace).appendChild(newdoc.createTextNode("false"))

    operation = newdoc.createElement('operation')
    request.appendChild(operation)

    authentication = newdoc.createElement('authentication')
    operation.appendChild(authentication)

    sessionid = newdoc.createElement('sessionid')
    authentication.appendChild(sessionid).appendChild(newdoc.createTextNode(sessionId))

    content = newdoc.createElement('content')
    operation.appendChild(content)
    function = newdoc.createElement('function')
    content.appendChild(function).setAttributeNode(newdoc.createAttribute('controlid'))
    function.attributes["controlid"].value = "testFunctionId"

    readByQuery = newdoc.createElement('readByQuery')
    function.appendChild(readByQuery)
    object = newdoc.createElement('object')
    readByQuery.appendChild(object).appendChild(newdoc.createTextNode("VENDOR"))
    fields = newdoc.createElement('fields')
    readByQuery.appendChild(fields).appendChild(newdoc.createTextNode("RECORDNO,VENDORID,NAME"))
    query = newdoc.createElement('query')
    readByQuery.appendChild(query).appendChild(newdoc.createTextNode("")) # All records

    # Post the request
    result = XMLRequestClient.post(request)

    # Print the XML response to the console
    print(result.toprettyxml())

except Exception as inst:
    print("Uh oh, something is wrong")
    print(type(inst))
    print(inst.args)