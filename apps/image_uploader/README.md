# ImageUploader

Uploads images to somewhere.

### IMGBB

#### pre-requisites

* It needs the IMGB API key setup in the env, which can be done by: `export IMGBB_API_KEY="my-key"`

In order to uploade images to IMGBB make sure you have all the images you want to upload on `priv/assets/images/**.png` 
and call the following function:

```Elixir
ImageUploader.upload_deck_to_imgbb!()
```
