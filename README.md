# Truco Paulista

## Setup

* This project requires Postgres 9.4+ 
* git clone git@github.com:feliperenan/truco.git
* mix deps.get
* mix deps.compile

### Running CI build locally

* Locally:
```bash
$ earthly -P +test
```

* From github:

```bash
$ earthly -P github.com/feliperenan/truco:master+test
```
