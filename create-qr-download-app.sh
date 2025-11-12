cho "NEW_PARNER_KEY: $NEW_PARNER_KEY"
echo "URL_IOS: $URL_IOS"
echo "URL_ANDROID: $URL_ANDROID"
echo "URL_HOME: $URL_HOME"

cd emddi-onelink
echo "Creating QR code for iOS"
node edit-partner-url.js $NEW_PARNER_KEY $URL_IOS $URL_ANDROID $URL_HOME

git fetch -p
git pull

echo "Creating QR code Done"
git add .
git commit -m "Update QR code for partner $NEW_PARNER_KEY"
git push

echo "Done"
echo "QR code for partner $NEW_PARNER_KEY: https://onelink.emddi.com/partner/$NEW_PARNER_KEY"