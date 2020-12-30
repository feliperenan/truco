# ImageUploader

Uploads images to somewhere.

### IMGBB

* First, you also need to create an account on https://imgbb.com
* Then set the `API_KEY` like so: `export IMGBB_API_KEY="my-key"`

In order to uploade images to IMGBB make sure you have all the images you want to upload on `priv/assets/images/**.png` 
and call the following function:

```Elixir
ImageUploader.upload_deck_to_imgbb!()
```
