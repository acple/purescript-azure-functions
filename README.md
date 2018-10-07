# purescript-azure-functions
Write AzureFunctions with PureScript

## Main
```purescript
module Main where

import Prelude

import Azure.Functions (AzureFunction, log, mkAzureFunction)

main :: forall t i. AzureFunction t i
main = mkAzureFunction do
  log "Hello sailor!"
  pure { status: "200", body: "This is response body." }
```

## Build
```sh
pulp build -O --skip-entry-point --to YourFunctions/index.js
echo 'module.exports=PS[\"Main\"].main;' >> YourFunctions/index.js
```
