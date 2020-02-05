#!/bin/bash

BASE_DIR='.'

function cleanup() {
  echo 'Cleanup existing keys'
  rspec ${BASE_DIR}/spec/lib/pgp/gpg/runner_integration_spec.rb > /dev/null

  listKeys
}

function listKeys() {
  echo 'List existing public keys'
  gpg --quiet --batch --list-keys --fingerprint

  echo 'List existing private keys'
  gpg --quiet --batch --list-secret-keys --fingerprint
}

function sectionStart() {
    echo ''
    echo $1
    echo '================================================'
}

function sectionEnd() {
    echo '================================================'
    echo ''
}

sectionStart 'Setup'
gpg --version
cleanup
sectionEnd


sectionStart 'Decrypt key without passphrase'
gpg --quiet --batch --import ${BASE_DIR}/spec/support/fixtures/private_key.asc
listKeys
echo 'Decrypting message'
rm -f /tmp/msg1.txt
gpg --quiet --batch --output /tmp/msg1.txt --decrypt ${BASE_DIR}/spec/support/fixtures/unencrypted_file.txt.asc
cat /tmp/msg1.txt
cleanup
sectionEnd


sectionStart 'Decrypt key with passphrase'
gpg --quiet --batch --import ${BASE_DIR}/spec/support/fixtures/private_key_with_passphrase.asc
listKeys
echo 'Decrypting message'
rm -f /tmp/msg1.txt
echo testingpgp | gpg --batch --yes --passphrase-fd 0 --output /tmp/msg1.txt --decrypt ${BASE_DIR}/spec/support/fixtures/encrypted_with_passphrase_key.txt.asc
cat /tmp/msg1.txt
cleanup
sectionEnd