# workable2bq

```
docker build -t workable2bq .
```

```
docker run -it -v $(pwd):/app -e WORKABLE_TOKEN=$WORKABLE_TOKEN -e WORKABLE_DOMAIN=$WORKABLE_DOMAIN workable2bq bash
```