import os
import email
from email import header
from imapclient.imapclient import IMAPClient
import requests
import sqlite3
import schedule
import time
import datetime
from email.parser import Parser
import re
import ipaddress
import sys
import json
import hashlib
import base64

if sys.version_info[0] >= 3:
    unicode = str

HOST = 'xxx'
USERNAME = 'xxx'
PASSWORD = 'xxx'
TOKEN = ['xxx']
GROUP_ID = ['xxx']
DATABASE = "notify.db"
cloud_networks = ['xxx']
idc_portal_webhook = 'xxx:port'


def initdb():
    conn = sqlite3.connect(DATABASE)
    cur = conn.cursor()
    cur.execute('''CREATE TABLE getmailid (
                  mailid VARCHAR(10) NOT NULL);'''
          )
    conn.commit()
    print("Create database successfull")
    conn.close()
def get_seen_id():
  ids = []
  conn = sqlite3.connect(DATABASE)
  cur = conn.cursor()
  cur.execute("SELECT mailid FROM getmailid")
  rows = cur.fetchall()
  for i in rows:
    ids.append(i[0])
  conn.close()
  return ids

def updateid(ids):
  conn = sqlite3.connect(DATABASE)
  for i in ids:
    conn.execute('''INSERT INTO getmailid(mailid) VALUES(?)''', (i,))
    print("Update %d" %(i))
  conn.commit()
  conn.close()
  return True

def notify(context):
    send_text = 'https://api.telegram.org/bot' +TOKEN[0]+ '/sendMessage?chat_id='+GROUP_ID[0]+'&parse_mode=Markdown&text='+context
    response = requests.get(send_text)

def notify_cloud(context):
    for i in range(len(TOKEN)):
        send_text = 'https://api.telegram.org/bot' +TOKEN[i]+ '/sendMessage?chat_id='+GROUP_ID[i]+'&parse_mode=Markdown&text='+context
        response_cloud = requests.get(send_text)

def notify_idc_portal(ip):
    url = "http://"+idc_portal_webhook+"/admin/v1/trigger"
    datetime_str = datetime.datetime.now().strftime('%d%m%Y')
    apikey = GenerateApiKey(datetime_str)
    payload = json.dumps({
          "Input": str(ip),
            "Type": "DDOS"
            })
    headers = {
              'ApiKey': apikey,
                'Content-Type': 'application/json'
                }
    response = requests.request("POST", url, headers=headers, data=payload)
    print(response.text)


def GenerateApiKey(datetime_str):
    key = "SMC2023AntiDDOS"
    total = key + datetime_str
    sha256 = hashlib.sha256()
    sha256.update(total.encode('utf-8'))
    bytes = sha256.digest()
    apikey = base64.b64encode(bytes).decode('utf-8')
    return apikey


def get_decoded_email_body(msg):
    text = ""
    p = Parser()
    message = p.parsestr(msg.as_string())
    for part in message.walk():
      if part.get_content_type() == 'text/plain':
        charset = part.get_content_charset()
        if charset == None:
          text += unicode(part.get_payload(decode=True), 'utf8', 'ignore')
          continue
        else:
          text += unicode(part.get_payload(decode=True), str(charset), 'ignore')
    if type(text) != type(u""):
        text = unicode(text, 'utf8')
    return text

def check_new_mail():
  body = ""
  spam = False
  exists = os.path.isfile(DATABASE)
  with IMAPClient(HOST,ssl=False) as server:
    server.login(USERNAME, PASSWORD)
    select_info = server.select_folder('INBOX', readonly=True)
    messages = server.search()
    
    if not exists:
      initdb()
      updateid(messages)
    else:
      id_list = get_seen_id()
      msg = []
      for i in messages:
        if str(i) not in id_list:
          msg.append(i)
      if len(msg) > 0:
        updateid(msg)
        print("You have %d new messages" %(len(msg)))
        print(msg)
        for uid, message in server.fetch(msg, 'RFC822').items():
          try:
            parsedmail = email.message_from_string(message[b'RFC822'].decode())
            mfrom, code = header.decode_header(parsedmail.get('From'))[0]
            if type(mfrom) != type(u""):
              mfrom = unicode(mfrom, 'utf8')
            context = str(datetime.datetime.now()) + "\n "+  mfrom +":"
            subject, encoding = header.decode_header(parsedmail.get('Subject'))[0]
            subject, encoding = header.decode_header(parsedmail.get('Subject'))[0]
            if encoding!=None:
              subject = subject.decode(encoding)
            if type(subject) != type(u""):
              subject = unicode(subject, 'utf8')
            context += "\n Subject: "+subject + "\n Content: "
            body = get_decoded_email_body(parsedmail)
            if type(context) != type(u""):
              body = unicode(context, 'utf8')
            context += body
            lcontext = len(context)
            if lcontext > 4096:
               print('length body: ', lcontext )
               context = context[0:4096]
            context = context.replace("*", "\\*")
            context = context.replace("_", "\\_")
            context = context.replace("`", '\\`')
            context = context.replace("[", '\\[')
            patterns = ["Message has been disinfected", "Message is infected"]
            for pattern in patterns:
              if re.search(pattern,context):
                spam = True
                print("Spam detected")
                break
            if not spam:
                ip = re.findall( r'[0-9]+(?:\.[0-9]+){3}', body )
                if ip:
                    for i in cloud_networks:
                        if ipaddress.ip_address(ip[0]) in ipaddress.ip_network(unicode(i)):
                            notify_cloud(context)
                            notify_idc_portal(ip[0])
                        else:
                            notify(context)
                else:
                    notify(context)                    
            print(body)
            print(context)
          except:
            print("Error read message: " + str(uid))

def clean_db():
  exists = os.path.isfile(DATABASE)
  if exists:
    os.remove(DATABASE)

schedule.every(5).seconds.do(check_new_mail)
schedule.every().sunday.at("20:00").do(clean_db)

while True:
  schedule.run_pending()
  time.sleep(1)
