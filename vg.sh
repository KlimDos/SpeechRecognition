#!/bin/bash

# Copyright 2017 Google Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create a request file with our JSON request in the current directory
FILENAME="request-"`date +"%s".json`
cat <<EOF > $FILENAME
{
  "config": {
    "encoding":"FLAC",
    "sampleRateHertz":16000,
    "profanityFilter": true,
    "languageCode": "ru-RU",
    "speechContexts": {
      "phrases": ['']
    },
    "maxAlternatives": 1
  },
  "audio": {
    "content":
	}
}
EOF

# Update the languageCode parameter if one was supplied
if [ $# -eq 1 ]
  then
    sed -i '' -e "s/en-US/$1/g" $FILENAME
fi

# Record an audio file, base64 encode it, and update our request object
read -p "Press enter when you're ready to record" rec
if [ -z $rec ]; then
  rec --channels=1 --bits=16 --rate=16000 audio.flac trim 0 5
  echo \"`base64 audio.flac -w 0`\" > audio.base64
  sed -i '' -e '/"content":/r audio.base64' $FILENAME
fi
echo Request "file" $FILENAME created:
head -7 $FILENAME # Don't print the entire file because there's a giant base64 string
echo $'\t"Your base64 string..."\n\x20\x20}\n}'

# Call the speech API (requires an API key)jq '.results[0].alternatives[0].transcript'
#read -p $'\nPress enter when you\'re ready to call the Speech API' var
#if [ -z $var ];
#  then
    echo "Running the following curl command:"
    echo "curl -s -X POST -H 'Content-Type: application/json' --data-binary @${FILENAME} https://speech.googleapis.com/v1/speech:recognize?key="
    curl -s -X POST -H "Content-Type: application/json" --data-binary @${FILENAME} https://speech.googleapis.com/v1/speech:recognize?key=$GKEY |jq '.results[0].alternatives[0].transcript' > ttext.txt
#fi

#================================




ttext=$(cat ttext.txt)

FILENAME="translate-"`date +"%s".json`
cat <<EOF > $FILENAME
{
'q': $ttext,
'target': 'en'
}
EOF

curl -k -X POST -H "X-Goog-Api-Key: $GKEY" --header "Content-type":"application/json" --data-binary @${FILENAME} "https://translation.googleapis.com/language/translate/v2"|jq '.data.translations[0].translatedText' > translate.txt
#curl -k -X POST -H "X-Goog-Api-Key: $GKEY" --header "Content-type":"application/json" --data-binary "@synt_settings" "https://translation.googleapis.com/language/translate/v2"|jq '.data[0].translations[0].translatedText' > translate.txt


#curl -s -X POST -H "Content-Type: application/json" --data-binary @${FILENAME} https://speech.googleapis.com/v1/speech:recognize?key=$GKEY |jq '.results[0].alternatives[0].transcript' > translate.txt
#=================================
ttext=$(cat translate.txt)

FILENAME="speech-"`date +"%s".json`
cat <<EOF > $FILENAME
{
  "audioConfig": {
     'audioEncoding':'MP3'
  },
  "voice": {
    "languageCode": "en-US",
    "name": "en-US-Wavenet-F"
  },
  "input": {
    "text": $ttext
  }
}
EOF

cat $FILENAME

curl -k -X POST -H "X-Goog-Api-Key: $GKEY" --header "Content-type":"application/json" --data-binary @${FILENAME} 'https://texttospeech.googleapis.com/v1beta1/text:synthesize' > synthesize-text.txt

Data123=$(cat synthesize-text.txt)
v2=${Data123:21:-3}
#v3=${v2:0:-3}
echo "$v2" > synthesize-output-base64.txt

base64 synthesize-output-base64.txt --decode > synthesized-audio.mp3

xplayer synthesized-audio.mp3
