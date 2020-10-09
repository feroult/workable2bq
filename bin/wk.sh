wk() {
      curl  -H "Content-Type: application/json" \
            -H "Authorization:Bearer $WORKABLE_TOKEN" \
            https://dextra.workable.com/spi/v3/$1 | json_pp
}

wk $*