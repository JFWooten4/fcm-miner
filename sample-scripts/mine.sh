#!/bin/bash

# Endpoint for retrieving block data.
# e.g. returns {"hash":"AAAAA...HlP9Q=","block":768,"difficulty":8}
data_endpoint="http://localhost:3000/data"

# Endpoint for submitting block data.
# e.g. Expecting /submit?hash=AAAAA...HlP9Q=&nonce=789990&message=HI&address=G...`
submit_endpoint="http://localhost:3000/submit"

# Starting nonce.
nonce=0

# Message.
message="HI"

# Miner Stellar address (trustline to FCM required).
miner_address="GCWS2AKJCZ6U4YTTSXPHSYMR5EWXSKKVZSRV22NROAI7YRFJUZMBB3FN"

# Miner executable.
miner_cmd="../miner"

# Max threads.
max_threads=10

# Batch size.
batch_size=5000000

# Verbose.
verbose=true

# Fetch block data.
response=$(curl -s "$data_endpoint")
new_hash=$(echo "$response" | sed -n 's/.*"hash":"\([^"]*\)".*/\1/p')
new_block=$(echo "$response" | sed -n 's/.*"block":\([0-9]*\).*/\1/p')
new_difficulty=$(echo "$response" | sed -n 's/.*"difficulty":\([0-9]*\).*/\1/p')
new_block=$((new_block + 1))

# Run miner.
echo "Running miner with hash=$new_hash, block=$new_block, difficulty=$new_difficulty, message=$message, address=$miner_address"
if $verbose; then
    output=$($miner_cmd "$new_block" "$new_hash" "$nonce" "$new_difficulty" "$message" "$miner_address" "--verbose" "--max-threads" "$max_threads" "--batch-size" "$batch_size" | tee /dev/tty)
else
    output=$($miner_cmd "$new_block" "$new_hash" "$nonce" "$new_difficulty" "$message" "$miner_address" "--max-threads" "$max_threads" "--batch-size" "$batch_size")
fi

# Retrieve hash and nonce.
mined_hash=$(echo "$output" | grep -oP '"hash": "\K[^"]+')
mined_nonce=$(echo "$output" | grep -oP '"nonce": \K\d+')
if [ -z "$mined_hash" ] || [ -z "$mined_nonce" ]; then
    exit 1
fi

# Submit to Stellar.
# I wanted to keep my private keys off the mining machine but you can also call the Stellar CLI directly here.
submit_url="${submit_endpoint}?hash=${mined_hash}&nonce=${mined_nonce}&message=${message}&address=${miner_address}"
echo "Submitting: $submit_url"
response=$(curl -s "$submit_url")
echo "$response"