# TrackFlow visual identity

An original trackpad outline, colored control edges, media points and flow
ribbon, released under the project's MIT license.

- mark.svg: editable vector.
- app-icon.png: 1024px macOS icon.
- TrackFlow/Assets.xcassets: native app/interface/template menu assets.

Regenerate rasters from the repository root with:

~~~sh
xcrun swift scripts/generate-brand.swift .
~~~

Preserve proportions and built-in margins; use the menu asset in system tint.
