
A UICollectionViewLayout subclass with flexbox feature.

Get tired of LeftAlignedCollectionViewFlowLayout or RightAlignedCollectionViewFlowLayout? How about BottomAlignedCollectionViewFlowLayout? Everything is done by UICollectionViewFlexboxLayout, inspired by the CSS flexbox.

![alt tag](https://raw.githubusercontent.com/Jerry0523/UICollectionViewFlexboxLayout/master/screenshot.gif)

Delegates
-------
### UICollectionViewDelegateFlowLayout( the system provided delegate)
```swift

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize

```
### UICollectionViewDelegateExtFlowLayout inherited from UICollectionViewDelegateFlowLayout

```swift
func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, showSectionBackgroundAt section: Int) -> Bool

```

### UICollectionViewDelegateFlexboxLayout  inherited from UICollectionViewDelegateExtFlowLayout

```swift
func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, justifyContentForSectionAt section: Int) -> UICollectionViewFlexboxLayout.JustifyContent?

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignItemsForSectionAt section: Int) -> UICollectionViewFlexboxLayout.AlignItems?

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexWrapForSectionAt section: Int) -> UICollectionViewFlexboxLayout.FlexWrap?

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignSelfForItemAt indexPath: IndexPath) -> UICollectionViewFlexboxLayout.AlignSelf

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexGrowForItemAt indexPath: IndexPath) -> CGFloat

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexShrinkForItemAt indexPath: IndexPath) -> CGFloat

```

License
-------
(MIT license)
