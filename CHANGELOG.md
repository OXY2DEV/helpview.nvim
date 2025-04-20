# Changelog

## [2.1.2](https://github.com/OXY2DEV/helpview.nvim/compare/v2.1.1...v2.1.2) (2025-04-20)


### Bug Fixes

* **renderer_vimdoc:** Fixed an issue with `enable` being matched as a config ([bdc38fa](https://github.com/OXY2DEV/helpview.nvim/commit/bdc38fa5bdb915d5091006ce19b87d12dc777b26)), closes [#28](https://github.com/OXY2DEV/helpview.nvim/issues/28)

## [2.1.1](https://github.com/OXY2DEV/helpview.nvim/compare/v2.1.0...v2.1.1) (2025-03-07)


### Bug Fixes

* **renderer_vimdoc:** Spacing fixes are now only applied when decorations are added ([d2d1294](https://github.com/OXY2DEV/helpview.nvim/commit/d2d129423e2cbea50cb395f50223d99316d22b46)), closes [#26](https://github.com/OXY2DEV/helpview.nvim/issues/26)

## [2.1.0](https://github.com/OXY2DEV/helpview.nvim/compare/v2.0.1...v2.1.0) (2025-02-21)


### Features

* **renderer_vimdoc:** Added support for `?` after arguments ([2841ca3](https://github.com/OXY2DEV/helpview.nvim/commit/2841ca37f5e9a0a527e63500485810f9def3b46a))


### Bug Fixes

* **core:** Check if it's possible to attach to a buffer ([2a77c8f](https://github.com/OXY2DEV/helpview.nvim/commit/2a77c8fc2992054fc650fc677ee83a37da5df783)), closes [#22](https://github.com/OXY2DEV/helpview.nvim/issues/22)
* **renderer_vimdoc:** Fixed compatibility issue with help tips on nightly ([30d3104](https://github.com/OXY2DEV/helpview.nvim/commit/30d3104fc44ea0dc50ccc4a68e7e65e70c34a2a4))

## [2.0.1](https://github.com/OXY2DEV/helpview.nvim/compare/v2.0.0...v2.0.1) (2025-02-05)


### Bug Fixes

* **trace:** Added missing traces ([8ca31bd](https://github.com/OXY2DEV/helpview.nvim/commit/8ca31bddd956c87d95b3478f3904b37049d73f15))

## [2.0.0](https://github.com/OXY2DEV/helpview.nvim/compare/v1.1.0...v2.0.0) (2025-02-05)


### Features

* **core:** Added health module & tracing capabilities ([dbfcfd6](https://github.com/OXY2DEV/helpview.nvim/commit/dbfcfd60ac9456b74b937cc223d8c31be7c72fb4))
* **core:** Wrapper command for `:help` ([37287c9](https://github.com/OXY2DEV/helpview.nvim/commit/37287c9a044d567fcb661cbd09670aeb91511c7f))
* **renderer_vimdoc:** Added custom renderer support ([0644c42](https://github.com/OXY2DEV/helpview.nvim/commit/0644c42a1d314d97027b102b02153b85bf5c4615))
* **vimdoc:** Added URL support ([db3df76](https://github.com/OXY2DEV/helpview.nvim/commit/db3df7695e06acee0d9a3dba61850d8c10d00c41))


### Bug Fixes

* **config:** Slightly tweaked th size of `:Help` window ([a6a904c](https://github.com/OXY2DEV/helpview.nvim/commit/a6a904c34051e4b11ecbf00851e0d2812ad03030))
* **core:** Added *partial* backwards compatibility ([b2f5c52](https://github.com/OXY2DEV/helpview.nvim/commit/b2f5c521cc46c87f443a3c41434c5b608b1e0dbf))
* **core:** Fixed a bug causing new buffers to not attach ([d6acaa9](https://github.com/OXY2DEV/helpview.nvim/commit/d6acaa9da4db1363db295d43882c58138169191e))
* **core:** Fixed a bug with `:H` not supporting completion ([60c8ca3](https://github.com/OXY2DEV/helpview.nvim/commit/60c8ca31b5f4d590d5e242ad1d47ca110fc8629b))
* **core:** Fixed a bug with the default values of `edit_range` ([d202f3c](https://github.com/OXY2DEV/helpview.nvim/commit/d202f3c7002fe4934f14004f72b93183a6643cf1))
* **core:** Fixed big causing preview decorations to multiply ([ba5fd70](https://github.com/OXY2DEV/helpview.nvim/commit/ba5fd70d422b95c73a986dab4616f7bd9bd85c15))
* Final typo fix ([ec48e34](https://github.com/OXY2DEV/helpview.nvim/commit/ec48e3449dc81b0cbcd83cdf082753789705ec27))
* Fixed CHANGELOG ([b2cd2ab](https://github.com/OXY2DEV/helpview.nvim/commit/b2cd2ab53472e69aa8e3439540b31df56b9393ff))
* fixed option mapping for highlight_groups ([c54666e](https://github.com/OXY2DEV/helpview.nvim/commit/c54666ec2f75b70563731f3e4a9b911695f1f23c))
* **highlights:** Fixed highlight group typo ([16b16d0](https://github.com/OXY2DEV/helpview.nvim/commit/16b16d0d4dc4d1291a393deab7e13922b22b4f4a))
* Incorrect dependency call fixes ([41d4e92](https://github.com/OXY2DEV/helpview.nvim/commit/41d4e92bb5c5550b25c1dd09dfad82f06d7c3b57))
* **parser_vimdoc:** Fixed a bug with highlight group names being highlighted without the group existing ([656bae7](https://github.com/OXY2DEV/helpview.nvim/commit/656bae784f1f29f89fc7dc3d6ccd69ab5e644ef0))
* **parser_vimdoc:** Fixed some label patterns ([79ddc1e](https://github.com/OXY2DEV/helpview.nvim/commit/79ddc1e06ff75379f52e560df92d937edeabd040))
* Updated modules ([0d15ec6](https://github.com/OXY2DEV/helpview.nvim/commit/0d15ec67cd1ed80806fb2bdde580ca236027123a))
* Updated the sorting function of `utils.match()` ([d67ff9e](https://github.com/OXY2DEV/helpview.nvim/commit/d67ff9eda8cfe8b2b51a2cfddf9308ed8c8fe47e))

## [1.1.0](https://github.com/OXY2DEV/helpview.nvim/compare/v1.0.1...v1.1.0) (2024-08-22)


### Bug Fixes

* Fixes broken release.

## [1.0.1](https://github.com/OXY2DEV/helpview.nvim/compare/v1.0.0...v1.0.1) (2024-08-22)


### Bug Fixes

* Added more fallback colors ([5509823](https://github.com/OXY2DEV/helpview.nvim/commit/55098234e989585d97d5c75d986358e58a4f72a7)), closes [#5](https://github.com/OXY2DEV/helpview.nvim/issues/5)
* Added validation for correct filetype for events ([c5e6446](https://github.com/OXY2DEV/helpview.nvim/commit/c5e6446135a2ef9790f543d21a2b4aff68b6a020)), closes [#8](https://github.com/OXY2DEV/helpview.nvim/issues/8)
* Added validation for setting highlight groups ([c51a6c9](https://github.com/OXY2DEV/helpview.nvim/commit/c51a6c9c861ce7b3f66138bff076af359e97e25e)), closes [#5](https://github.com/OXY2DEV/helpview.nvim/issues/5)
* Fixed a priority related bug in inline elements ([c593ecd](https://github.com/OXY2DEV/helpview.nvim/commit/c593ecd87f02be5e2414155e4c95e123d75333de)), closes [#9](https://github.com/OXY2DEV/helpview.nvim/issues/9)
* More highlight groups now respect default groups from colorschemes ([336d731](https://github.com/OXY2DEV/helpview.nvim/commit/336d7318add97f0f421dba3b1741055ec8d345ac)), closes [#7](https://github.com/OXY2DEV/helpview.nvim/issues/7)
* Removed unnnecessary "opts.default" ([e67b9e4](https://github.com/OXY2DEV/helpview.nvim/commit/e67b9e4930a6db069eea7b0f9af8366539df5c94)), closes [#5](https://github.com/OXY2DEV/helpview.nvim/issues/5)
* **renderer:** Fixed incorrect overlay text position of inline elements ([7795341](https://github.com/OXY2DEV/helpview.nvim/commit/77953412d13dc7d38a32042c66398a681100b3a1)), closes [#9](https://github.com/OXY2DEV/helpview.nvim/issues/9)

## 1.0.0 (2024-08-12)


### Features

* Added hybrid mode to the plugin ([9de7d93](https://github.com/OXY2DEV/helpview.nvim/commit/9de7d9370d32150ba6a77550c1a6c5c8cbee421b))


### Bug Fixes

* Fixed various bugs related to the new defaults ([e88ce30](https://github.com/OXY2DEV/helpview.nvim/commit/e88ce3061ad42725576da640922a2c84aef4a7ec))
* Improved rendering mechanics ([9de7d93](https://github.com/OXY2DEV/helpview.nvim/commit/9de7d9370d32150ba6a77550c1a6c5c8cbee421b))
* Replaced options with callbacks ([9de7d93](https://github.com/OXY2DEV/helpview.nvim/commit/9de7d9370d32150ba6a77550c1a6c5c8cbee421b))
* Tweaked how titles & headings are rendered ([9de7d93](https://github.com/OXY2DEV/helpview.nvim/commit/9de7d9370d32150ba6a77550c1a6c5c8cbee421b))
* Various bug fixes from `markview.nvim` ([331d5f7](https://github.com/OXY2DEV/helpview.nvim/commit/331d5f740ad6f3f36976b76b8be75c10b61afbed))
