using System;
using System.Collections.Generic;
using Shaders.PaletteSwap;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal.ShaderGUI;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace Shaders.Editors
{
    internal class TexelShader : BaseShaderGUI
    {
        static readonly string[] workflowModeNames = Enum.GetNames(typeof(LitGUI.WorkflowMode));

        private TexelShaderGui.LitProperties litProperties;
    }
}
