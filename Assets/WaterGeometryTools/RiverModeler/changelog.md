1.0.4

Added:
- Support for Stylized Water 3. Will automatically use its river material when creating one.
- Rebuild Triggers dropdown, controls which events cause the river to rebuild.
- Spline Change Mode parameter, allows delaying the mesh generation until after the spline changes are done.
- Water splash VFX graph now has a Cull Distance parameter. Particles beyond this distance (from the camera) are killed off.
- Transparency: start/end fade length parameters.
- Preference menu: Option to disable rebuilding every frame.

Changed:
- Bounds for VFX is now pre-calculated, this allows rendering to be skipped when VFX fall outside of view.

Fixed:
- Microverse: Bed smoothness incorrectly affecting the bed depth, it now correctly smooths the borders only

1.0.3

Changed:
- Component will no longer throw an error when attempting to create a river from an empty spline, instead it silently ignores them.

Fixed:
- Possible false-positive warning message in VFX components regarding a broken VFX Graph

1.0.2

Added:
- Option under the UV section to store the rivers flow direction into the UV3 channel.

Changed:
- If a Mesh Collider is attached to the river, its mesh is now also updated

1.0.1

Added:
- Support for mesh generation from multiple splines within a single container.
- Automatic FBX file exporting and syncing.
- VFX Graph: exposed curves for Size and Opacity over lifetime

Fixed:
- Error in inspector code that prevented a SplineContainer object from being dragged into the related field.

1.0.0
Initial release (March 4 2024)