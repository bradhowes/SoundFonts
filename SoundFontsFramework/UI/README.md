#  Storyboards

* `SoundFontsControls` -- top-level storyboard that just has embedded segues to others
* `FontsView` -- shows two table views, one with the list of available SF2 files, and the other with the list of patches found in the SF2 file that is selected in the first view
* `FavoritesView` -- shows the set of favorited patches
* `InfoBar` -- defines the controls and status areas found between the table views and the keyboard
* `SettingsView` -- collection of runtime parameters and actions
* `GuidView` -- descriptions that appear when the user selects the '?' button
* `FontEditor` -- modal view that allows for editing of SF2 data
* `FavoriteEditor` -- modal view that allows for editing of favorite info
* `Tutorial` -- views and content for the tutorial pages that appear when first running the application

# NIB / XIB Files

* `FavoriteCell` -- layout for a favorite entry in the FavoritesView collection
* `TableCell` -- layout for a font or a patch entry in the FontsView table views
