// Stylized Water 3 by Staggart Creations (http://staggart.xyz)
// COPYRIGHT PROTECTED UNDER THE UNITY ASSET STORE EULA (https://unity.com/legal/as-terms)
//   • Copying or referencing source code for the production of new asset store, or public, content is strictly prohibited!
//   • Uploading this file to a public repository will subject it to an automated DMCA takedown request.

using System;
using UnityEditor;
using UnityEngine;

namespace StylizedWater3
{
    [CustomEditor(typeof(OceanFollowBehaviour))]
    public class OceanFollowBehaviourInspector : Editor
    {
        private SerializedProperty material;
        private SerializedProperty enableInEditMode;
        private SerializedProperty followTarget;

        private void OnEnable()
        {
            material = serializedObject.FindProperty("material");
            enableInEditMode = serializedObject.FindProperty("enableInEditMode");
            followTarget = serializedObject.FindProperty("followTarget");
        }

        private bool materialChanged;
        
        public override void OnInspectorGUI()
        {
            UI.DrawHeader();

            serializedObject.Update();
            
            EditorGUI.BeginChangeCheck();
            
            using (new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Space(EditorGUIUtility.labelWidth);
                OceanFollowBehaviour.ShowWireFrame = GUILayout.Toggle(OceanFollowBehaviour.ShowWireFrame, new GUIContent("  Show Wireframe", EditorGUIUtility.IconContent((OceanFollowBehaviour.ShowWireFrame ? "animationvisibilitytoggleon" : "animationvisibilitytoggleoff")).image), "Button");
            }
            
            EditorGUILayout.Separator();
            
            using (new EditorGUILayout.HorizontalScope())
            {
                materialChanged = false;
                EditorGUI.BeginChangeCheck();
                EditorGUILayout.PropertyField(material);

                if (EditorGUI.EndChangeCheck()) materialChanged = true;
                
                EditorGUI.BeginDisabledGroup(material.objectReferenceValue == null);
                if (GUILayout.Button("Edit", EditorStyles.miniButton, GUILayout.Width(50f)))
                {
                    Selection.activeObject = material.objectReferenceValue;
                    //StylizedWaterEditor.PopUpMaterialEditor.Create(material.objectReferenceValue);
                }
                EditorGUI.EndDisabledGroup();
            }
            EditorGUILayout.Separator();
            
            EditorGUILayout.PropertyField(enableInEditMode);
            EditorGUILayout.PropertyField(followTarget);
            if (followTarget.objectReferenceValue == null)
            {
                EditorGUILayout.HelpBox("None assigned. The actively rendering camera will be automatically followed", MessageType.Info);
            }

            if (EditorGUI.EndChangeCheck())
            {
                serializedObject.ApplyModifiedProperties();

                if (materialChanged)
                {
                    OceanFollowBehaviour component = (OceanFollowBehaviour)target;
                    component.ApplyMaterial();
                }
            }
            
            UI.DrawFooter();
        }
    }
}