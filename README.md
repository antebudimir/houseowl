
<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./docs/docs/img/icon.png">
    <img width="128" src="./docs/docs/img/logo.png" alt="HouseOwl">
  </picture>
</h1>

<p align="center">A smart, self-hosted household manager.</p>

<h4 align="center">
  <a href="https://github.com/antebudimir/houseowl">Source</a> |
  <a href="https://github.com/antebudimir/houseowl/blob/main/CHANGELOG.md">Changelog</a>
</h4>

<h4 align="center">
  <a href="https://github.com/antebudimir/houseowl">
    <img alt="Stars" src="https://img.shields.io/github/stars/antebudimir/houseowl" />
  </a>
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/antebudimir/houseowl" />
  </a>
  <a href="https://ghcr.io/antebudimir/houseowl">
    <img alt="Container image" src="https://img.shields.io/badge/ghcr.io-antebudimir%2Fhouseowl-blue" />
  </a>
</h4>

HouseOwl is a smart self-hosted household manager. Easily add items to your
shopping list before you go shopping, manage tasks, notes, birthdays, events,
and documents for everyone in your household.

- Native Mobile/Web/Desktop apps with a great design
- Add items to your shopping list and sync them in real-time with multiple users
- Partial offline support, so you don't lose track of what to buy even when there is no signal
- Manage tasks, notes, persons (with birthdays and gift ideas), and documents
- Share your household with friends and family

Please keep in mind that this project is still in development.

## 🍴 About this fork

This is a hard fork of [KitchenOwl](https://github.com/kitchenowl/kitchenowl) (upstream: [TomBursch/kitchenowl](https://github.com/TomBursch/kitchenowl)),
evolving it from a grocery list and recipe manager toward a broader household
coordination app.

Changes from upstream:

- Recipes and expenses removed
- Tasks, notes, events, and persons (with birthdays and gift ideas) added
- Shopping lists managed inline from the main-view header (add, rename, delete; long-press for actions)
- Shopping-list renames sync to all household members in real time
- Rebranded from KitchenOwl to HouseOwl

See [CHANGELOG.md](CHANGELOG.md) for the full history of fork changes.

## 📱 Screenshots

TO BE ADDED

## 🤖 App Install

There are no store builds of this fork. Run the web app via the docker images
below, or build the mobile/desktop apps from source:

```sh
git clone https://github.com/antebudimir/houseowl
cd houseowl/kitchenowl
flutter pub get
flutter gen-l10n   # required on fresh clones before the first build
flutter run
```

> **Note (Android):** the app id changed from `com.tombursch.kitchenowl` to
> `com.antebudimir.houseowl`. Android treats this as a different app —
> in-place upgrades from KitchenOwl are not possible; install fresh.

## 🚀 Get started (self-hosting)

```sh
mkdir houseowl && cd houseowl
wget https://raw.githubusercontent.com/antebudimir/houseowl/main/docker-compose.yml
podman compose up -d
```

For advanced setups see the [upstream self-hosting docs](https://docs.kitchenowl.org/latest/self-hosting/)
(still accurate except for image names and `podman compose`).

## 🙌 Contributing

From opening a bug report to creating a pull request: every contribution is appreciated and welcomed. If you're planning to implement a new feature or change the API please create an issue first. This way, we can ensure your work is not in vain.
For more information see [Contributing](CONTRIBUTING.md).

### 🌍 Translations

Translations live in `kitchenowl/lib/l10n/*.arb`. Add or edit strings there and
run `flutter gen-l10n`.

## 📚 Related

- [Docs (source)](https://github.com/antebudimir/houseowl/tree/main/docs)

### 🔨 Built With

- [Flask](https://flask.palletsprojects.com/)
- [Flutter](https://flutter.dev/)
- [Podman](https://podman.io/)

## 🍀 Contributors

Includes everyone from the upstream KitchenOwl history this fork is built on.

<a href="https://github.com/antebudimir/houseowl/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=antebudimir/houseowl" />
</a>

## 📜 License

HouseOwl is Free Software: You can use, study share and improve it at your will. Specifically you can redistribute and/or modify it under the terms of the AGPL-3.0 License.
