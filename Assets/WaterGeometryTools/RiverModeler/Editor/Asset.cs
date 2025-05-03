using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace sc.modeling.river.editor
{
    public static class Asset
    {
        public const string NAME = "River Modeler";
        public const string VERSION = "1.0.4";
        public const int ID = 263898;

        #region Installer
        internal abstract class Installer : sc.modeling.water.common.editor.PackageInstaller
        {
            private static readonly string[] requiredPackages = 
            {
                "com.unity.splines@2.3.0", 
                "com.unity.mathematics", 
                "com.unity.visualeffectgraph",
                "com.unity.shadergraph"
            };
            
            //Symbols defined by assembly definition
            #if !SPLINES || !MATHEMATICS || !VFX_GRAPH || !SHADERGRAPH
            [InitializeOnLoadMethod]
            private static void AutoInstall()
            {
                InstallDependencies(NAME, requiredPackages);
            }

            [MenuItem("River Modeler/Install dependencies")]
            private static void InstallMenuFunction()
            {
                AutoInstall();
            }
            #endif

        }
        #endregion
        
        public static class Preferences
        {
            public static bool ShowToolPoints
            {
                get => EditorPrefs.GetBool(PlayerSettings.productName + "_RIVER_EDITOR_ShowToolPoints", false);
                private set => EditorPrefs.SetBool(PlayerSettings.productName + "_RIVER_EDITOR_ShowToolPoints", value);
            }
            
            public static bool RebuildEveryFrame
            {
                get => EditorPrefs.GetBool(PlayerSettings.productName + "_RM_RebuildEveryFrame", true);
                set => EditorPrefs.SetBool(PlayerSettings.productName + "_RM_RebuildEveryFrame", value);
            }
            
            [SettingsProvider]
            public static SettingsProvider ScreenshotSettings()
            {
                var provider = new SettingsProvider($"Preferences/Water Geometry Tools/River", SettingsScope.User)
                {
                    label = "River Editor",
                    guiHandler = (searchContent) =>
                    {
                        EditorGUILayout.LabelField($"v{Asset.VERSION}", EditorStyles.miniLabel);
                        EditorGUILayout.Space();
                        
                        ShowToolPoints = EditorGUILayout.ToggleLeft("Show tool points", ShowToolPoints);
                        EditorGUILayout.HelpBox("When enabled, data points for tools such as Width and Opacity will always be displayed on rivers, even when not active.\n\n", MessageType.Info);
                        
                        
                        RebuildEveryFrame = EditorGUILayout.Toggle("Rebuild every frame", RebuildEveryFrame);
                        EditorGUILayout.HelpBox("When disabled, the river mesh is rebuild at a lower frame rate when changing parameters in the inspector. This yields better editor performance." +
                                                "\n\nWhen enabled, rebuilding occurs every time the UI repaints (much smoother)", MessageType.Info);


                        using (new EditorGUILayout.HorizontalScope())
                        {
                            GUILayout.FlexibleSpace();
                            if (GUILayout.Button("Rebuild all instances in scene"))
                            {
                                int count = RiverEditor.RebuildAllInstances();
                                Debug.Log($"Rebuilt {count} River Modeler component instances.");
                            }
                        }
                    },

                    keywords = new HashSet<string>(new[]
                    {
                        "River"
                    })
                };

                return provider;
            }
        }
    }
}