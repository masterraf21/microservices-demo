# apiservice

This is a stripped down version of the `frontend` application that just return json.
ex:

```
curl -s "http://apiservice:8080/api/v1/"|jq '.'
curl -s "http://apiservice:8080/api/v1/product/OLJCESPC7Z"|jq '.'
```