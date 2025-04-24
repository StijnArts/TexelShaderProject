using UnityEditor;

namespace Shaders.PaletteSwap
{
    public class TexelShaderGui
    {
        public struct LitProperties
        {
            // public MaterialProperty baseColor;

            /// <summary>
            /// The MaterialProperty for selecting the workflow mode.
            /// </summary>
            public MaterialProperty workflowModeProp;

            /// <summary>
            /// The MaterialProperty for the source palette texture.
            /// </summary>
            public MaterialProperty paletteTexProp;

            /// <summary>
            /// The MaterialProperty for the target palette texture.
            /// </summary>
            public MaterialProperty targetPaletteTexProp;

            /// <summary>
            /// The MaterialProperty for color offset between palette entries.
            /// </summary>
            public MaterialProperty colorOffsetProp;

            /// <summary>
            /// The MaterialProperty for toggling palette-based or color-based rendering.
            /// </summary>
            public MaterialProperty useColorProp;

            /// <summary>
            /// The MaterialProperty for the scale of the normal map.
            /// </summary>
            public MaterialProperty bumpScaleProp;

            /// <summary>
            /// The MaterialProperty for the normal map texture.
            /// </summary>
            public MaterialProperty bumpMapProp;

            /// <summary>
            /// The MaterialProperty for enabling/disabling highlights.
            /// </summary>
            public MaterialProperty doHighlightsProp;

            /// <summary>
            /// The MaterialProperty for surface smoothness (affects highlights/reflections).
            /// </summary>
            public MaterialProperty smoothnessProp;

            /// <summary>
            /// The MaterialProperty for enabling emission.
            /// </summary>
            public MaterialProperty useEmissionProp;

            /// <summary>
            /// The MaterialProperty for emission color.
            /// </summary>
            public MaterialProperty emissionColorProp;

            /// <summary>
            /// The MaterialProperty for the emission map texture.
            /// </summary>
            public MaterialProperty emissionMapProp;

            /// <summary>
            /// The MaterialProperty for emission intensity.
            /// </summary>
            public MaterialProperty emissionIntensityProp;

            /// <summary>
            /// The MaterialProperty for controlling additional light segmentation.
            /// </summary>
            public MaterialProperty additionalLightSegmentationProp;

            /// <summary>
            /// Constructor for the <c>LitProperties</c> container struct.
            /// </summary>
            /// <param name="properties"></param>
            public LitProperties(MaterialProperty[] properties)
            {
                // Surface Option Props
                workflowModeProp = BaseShaderGUI.FindProperty("_WorkflowMode", properties, false);

                // Surface Input Props
                paletteTexProp = BaseShaderGUI.FindProperty("_PaletteTex", properties);
                targetPaletteTexProp = BaseShaderGUI.FindProperty("_TargetPaletteTex", properties);
                colorOffsetProp = BaseShaderGUI.FindProperty("_ColorOffset", properties, false);
                useColorProp = BaseShaderGUI.FindProperty("_UseColor", properties, false);
                bumpScaleProp = BaseShaderGUI.FindProperty("_BumpScale", properties, false);
                bumpMapProp = BaseShaderGUI.FindProperty("_BumpMap", properties, false);

                // Highlight and Smoothness
                doHighlightsProp = BaseShaderGUI.FindProperty("_DoHighlights", properties, false);
                smoothnessProp = BaseShaderGUI.FindProperty("_Smoothness", properties, false);

                // Emission
                useEmissionProp = BaseShaderGUI.FindProperty("_UseEmission", properties, false);
                emissionColorProp = BaseShaderGUI.FindProperty("_EmissionColor", properties, false);
                emissionMapProp = BaseShaderGUI.FindProperty("_EmissionMap", properties, false);
                emissionIntensityProp = BaseShaderGUI.FindProperty("_EmissionIntensity", properties, false);

                // Additional Light Settings
                additionalLightSegmentationProp = BaseShaderGUI.FindProperty("_AdditionalLightSegmentation", properties, false);
            }
        }
    }
}