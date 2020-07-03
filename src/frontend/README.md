# frontend

## Usage

### Change the banner color

Set environment variable `BANNER_COLOR` to a known color name (red, blue, green, orange...) to change the banner color. Use it to simulate two different versions of the application


## Build

Run the following command to restore dependencies to `vendor/` directory:

    dep ensure --vendor-only

## Changes

### 20200318 - adservice
As of version v0.1.6 the frontend application calls the REST version of the `adservice` (from `src/adservice2`)