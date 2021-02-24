import re
import requests
import json

class netease:
  def __init__(self, url):
    self.url = url
    self.link = 'https://music.163.com/api/song/lyric?lv=-1&kv=-1&tv=-1&os=pc&id='
    self.headers = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:58.0) Gecko/20100101 Firefox/58.0' }
  
  def get_song_id(self):
    # '/org/mpris/MediaPlayer2/32574583'
    if self.url != "":
      id = re.split('/', self.url)[-1]
      return id
    else:
      return ""

  def get_lyrics(self):
    id = self.get_song_id()
    if id != "":
      web_data = requests.get(url = self.link + id, headers = self.headers).text
      json_data = json.loads(web_data)
      try:
        return json_data['lrc']['lyric']
      except BaseException:
        return ""
    else:
      return ""

def calc_seconds(str):
  m, s = str.split(':')
  return float(m) * 60 + float(s)

def resolve(lyrics):
  lines = lyrics.split('\n')
  for i in lines:
    j = i[1:].split(']')
    if len(j) == 2:
      if j[1].strip() == "":
        continue
      print('%f#%s' % (calc_seconds(j[0]), j[1].strip()))

url = input()
net = netease(url)
lyrics = net.get_lyrics().strip()
if lyrics == "":
  exit(1)
resolve(lyrics)