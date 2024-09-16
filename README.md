# Der junge Goethe in seiner Zeit

[![License][license-img]][license-url]
[![GitHub release][release-img]][release-url]
![exist-db CI](https://github.com/cophiwue/jgoethe/workflows/exist-db%20CI/badge.svg)

### Development

Running `ant` creates two `.xar` files in the `build` directory. Deploy the `-dev` one to the local exist-db instance, it will show up in `/db/apps/jgoethe`. Open any of the files of the app in eXide, and then choose Application → Synchronize → [x] Synchronize automatically to sync the contents with the original folder, enabling working on it in eXide and commiting using git.

### Running the image

```bash
docker run -d --name jgoethe -e EXIST_ENV=production -p 8765:8080 thvitt/jgoethe:latest
```

… runs the image in a background process (`-d`) and in production mode, exposing the web app at port 8765, ready to be proxied.

### Building from source

```bash
docker build --no-cache --tag=thvitt/jgoethe:latest .
```

## License

TODO

<!-- 

[license-img]: https://img.shields.io/badge/license-AGPL%20v3-blue.svg
[license-url]: https://www.gnu.org/licenses/agpl-3.0
[release-img]: https://img.shields.io/badge/release-0.1.0-green.svg
[release-url]: https://github.com/cophiwue/jgoethe/releases/latest

-->
