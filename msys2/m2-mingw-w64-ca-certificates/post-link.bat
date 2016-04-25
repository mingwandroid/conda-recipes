@echo MINGW-packages\mingw-w64-ca-certificates\ca-certificates-x86_64.install rewritten as Conda post-link.bat
@echo             .. instead I should be calling the bash script directly ..
@set LC_ALL=C
@set DEST=mingw-w64/etc/pki/ca-trust/extracted
@pushd %PREFIX%\Library
@mingw-w64\bin\p11-kit extract --format=openssl-bundle --filter=certificates --overwrite %DEST%/openssl/ca-bundle.trust.crt
@mingw-w64\bin\p11-kit extract --format=pem-bundle --filter=ca-anchors --overwrite --purpose server-auth %DEST%/pem/tls-ca-bundle.pem
@mingw-w64\bin\p11-kit extract --format=pem-bundle --filter=ca-anchors --overwrite --purpose email %DEST%/pem/email-ca-bundle.pem
@mingw-w64\bin\p11-kit extract --format=pem-bundle --filter=ca-anchors --overwrite --purpose code-signing %DEST%/pem/objsign-ca-bundle.pem
@mingw-w64\bin\p11-kit extract --format=java-cacerts --filter=ca-anchors --overwrite --purpose server-auth %DEST%/java/cacerts

@usr\bin\mkdir -p mingw-w64/ssl/certs
@usr\bin\cp -f %DEST%/pem/tls-ca-bundle.pem mingw-w64/ssl/certs/ca-bundle.crt
@usr\bin\cp -f %DEST%/pem/tls-ca-bundle.pem mingw-w64/ssl/cert.pem
@usr\bin\cp -f %DEST%/openssl/ca-bundle.trust.crt mingw-w64/ssl/certs/ca-bundle.trust.crt
@popd
