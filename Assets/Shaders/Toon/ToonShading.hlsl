#include "Assets/Shaders/Toon/ToonInput.hlsl"
#include "Assets/Shaders/Texel/TexelFunctions.hlsl"


float4 GetMainLightToonFactor(float NdotL)
{
    float firstTransition = smoothstep(_FirstShade - _FirstShadeTransitionSoftness,
                                       _FirstShade + _FirstShadeTransitionSoftness, NdotL);
    float secondTransition = smoothstep(_SecondShade - _SecondShadeTransitionSoftness,
                                        _SecondShade + _SecondShadeTransitionSoftness, NdotL);
    float4 color = lerp(.8, 1, firstTransition);
    color = lerp(.7, color, secondTransition);

    return color;
}

half GetSpecularTerm(BRDFData brdfData, Varyings i, Light light, float3 viewDirection)
{
    if (!_DoHighlights /*|| toonLevel < _FirstShade*/)
        return 0;

    float3 lightDirectionWSFloat3 = float3(light.direction);
    float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirection));

    float NoH = saturate(dot(float3(i.normalWS), halfDir));
    half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));
    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
    return specularTerm;
}

float3 CalculateCellSpecular(BRDFData brdfData, Varyings i, Light light, float3 viewDirection, float toonLevel)
{
    if (!_DoHighlights) return float3(0, 0, 0);
    // return specularTerm;
    // return light.color.rgb * _HighlightColor.rgb * specularTerm * light.shadowAttenuation;
    // Normalize vectors
    float3 lightDirection = normalize(light.direction);
    float3 normal = normalize(i.normalWS);
    viewDirection = normalize(viewDirection);
    // viewDirection = CalculateSnappedWorldViewDir(viewDirection, lightDirection);
    // Calculate half-vector for Blinn-Phong
    float3 halfVector = normalize(lightDirection + viewDirection);
    
    // Compute specular term
    float NdotH = max(0.0, dot(normal, halfVector));
    float specularFactor = pow(NdotH, _HighlightSize);
    // return specularRange*_HighlightSize;
    if (specularFactor < _HighlightSize) return 0;
    // Apply light intensity and specular color
    return light.color.rgb * _HighlightColor.rgb * light.shadowAttenuation * light.distanceAttenuation; //+ _HighlightIntensity;
}

float3 GetAdditionalLights(Varyings i,
    InputData inputData,
    BRDFData brdfData,
    half4 shadowMask,
    uint meshRenderingLayers,
    AmbientOcclusionFactor aoFactor,
    float3 viewDirection)
{
    float3 additionalLightsColor = 0;
    uint pixelLightCount = GetAdditionalLightsCount();
    #if USE_FORWARD_PLUS
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS);
                lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        
        #ifdef _LIGHT_LAYERS
                        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        #endif
        {
                            
                            float NdotL_Additional = max(0.0, dot(normalize(inputData.normalWS), normalize(light.direction)));
                            #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
                            half4 occlusionProbeChannels = _AdditionalLightsBuffer[lightIndex].occlusionProbeChannels;
                            #else
                            half4 occlusionProbeChannels = _AdditionalLightsOcclusionProbes[lightIndex];
                            #endif
                            float additionalShadowFactor = AdditionalLightShadow(
                                lightIndex, i.positionWS, light.direction, half4(1, 1, 1, 1), occlusionProbeChannels);
                            // Toon shading: Quantize the light intensity into discrete levels
                            float quantizedLight = floor(NdotL_Additional / _AdditionalLightSegmentation) *
                                _AdditionalLightSegmentation;
                            float3 attenuatedLightColor = light.color *
                                (light.distanceAttenuation * additionalShadowFactor * quantizedLight);
                            additionalLightsColor += attenuatedLightColor * NdotL_Additional;
                            if (attenuatedLightColor.x != 0 && attenuatedLightColor.y != 0 && attenuatedLightColor.z != 0);
        }
    }
    #endif
    
    LIGHT_LOOP_BEGIN(pixelLightCount)

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        #ifdef _LIGHT_LAYERS
                        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        #endif
        {
                            float NdotL_Additional = max(0.0, dot(normalize(inputData.normalWS), normalize(light.direction)));
                            #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
                            half4 occlusionProbeChannels = _AdditionalLightsBuffer[lightIndex].occlusionProbeChannels;
                            #else
                            half4 occlusionProbeChannels = _AdditionalLightsOcclusionProbes[lightIndex];
                            #endif
                            float additionalShadowFactor = AdditionalLightShadow(
                                lightIndex, i.positionWS, light.direction, half4(1, 1, 1, 1), occlusionProbeChannels);
                            // Toon shading: Quantize the light intensity into discrete levels
                            float quantizedLight = floor(NdotL_Additional / _AdditionalLightSegmentation) *
                                _AdditionalLightSegmentation;
                            float3 attenuatedLightColor = light.color *
                                (light.distanceAttenuation * additionalShadowFactor * quantizedLight);
                            additionalLightsColor += attenuatedLightColor * NdotL_Additional;
                            if (attenuatedLightColor.x != 0 && attenuatedLightColor.y != 0 && attenuatedLightColor.z != 0)
                                additionalLightsColor += CalculateCellSpecular(brdfData, i, light, viewDirection, quantizedLight);
        }
    LIGHT_LOOP_END
    /*float3 additionalLightsColor = 0;
    LIGHT_LOOP_BEGIN(GetAdditionalLightsCount())
        
    LIGHT_LOOP_END
    return additionalLightsColor;*/
    return additionalLightsColor;
}

float4 GetBaseShadingColor(float NdotL, float2 uv)
{
    // Calculate smooth transitions
    float firstTransition = smoothstep(_FirstShade - _FirstShadeTransitionSoftness,
                                                               _FirstShade + _FirstShadeTransitionSoftness,
                                                               NdotL);
    float secondTransition = smoothstep(_SecondShade - _SecondShadeTransitionSoftness,
                                                                _SecondShade +
                                                                _SecondShadeTransitionSoftness,
                                                                NdotL);
    // Blend colors based on transitions
    float4 color = lerp(_SecondShadeColor, _FirstShadeColor, firstTransition);
    // Transition between second and first shade
    color = lerp(_ThirdShadeColor, color, secondTransition);
    // Transition between third and the result of first-second blend

    return color;
}

float4 GetPaletteBaseShadingColor(Light mainLight, float toonLevel, float2 uv, half specular)
{
    // return specular;
    float4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

    [loop]
    for (int i = 0; i < _PaletteLength; i++)
    {
        if (i >= (int)_PaletteLength) return float4(0,1,0,1);

        float texelWidth = _TargetPaletteTex_TexelSize.x;
        float u = (i + 0.5) * texelWidth;

        float4 srcCol = SAMPLE_TEXTURE2D(_PaletteTex, sampler_PaletteTex, float2(u, 0.5));
        if (all(abs(col.rgb - srcCol.rgb) < 0.001))
        {
            float lighting = toonLevel -.5;
            float texelHeight = _TargetPaletteTex_TexelSize.y;

            lighting = saturate((lighting + 1.0) * 0.5);
            float4 color = SAMPLE_TEXTURE2D(_TargetPaletteTex, sampler_TargetPaletteTex, float2(u, lighting));

            float4 highlightColor = SAMPLE_TEXTURE2D(_TargetPaletteTex, sampler_TargetPaletteTex, float2(u, 1.0 - texelHeight * 0.5));

            float lightingStrength = smoothstep(0, 1.0, specular);

            color.rgb += highlightColor.rgb * mainLight.color * lightingStrength;

            // Optional: clamp to avoid overbright colors
            color = saturate(color);

            return color;
        }
    }

    return col;
}

half4 GetFinalToonColor(Varyings input, InputData inputData, SurfaceData surfaceData, bool usePalette)
{
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    //Custom shading
    float4 mainLightIntensity;
    float3 colorCalculatedForThisFragment = float3(1, 1, 1);
    //just for testing, in reallity you would want to calculate distance and angle.
    mainLightIntensity.rgb = colorCalculatedForThisFragment * mainLight.color;
    mainLightIntensity.a = 1;
    // return mainLightIntensity;
    mainLightIntensity = max(mainLightIntensity, float4(1, 1, 1, 1));
    float NdotL = dot(normalize(input.normalWS), normalize(mainLight.direction));
    float toonLevel = min(NdotL, mainLight.shadowAttenuation);
    // Set the fragment color to the shadow value
    float4 col;
    if (_UseColor)
    {
        col = _Color;
    } else
    {
        col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    }
    float4 toonColor;
    if (usePalette) toonColor = GetPaletteBaseShadingColor(mainLight, toonLevel, input.uv,
        GetSpecularTerm(brdfData, input, mainLight, inputData.viewDirectionWS)*surfaceData.specular);
    else toonColor = GetBaseShadingColor(toonLevel, input.uv);
    if (usePalette) return toonColor;
    // return toonColor;
    if (usePalette) col = toonColor;
    float4 mainLightToonFactor = usePalette ? 1 : GetMainLightToonFactor(toonLevel);
    float mainLightIntensityFactor = .2 * mainLightIntensity;
    float3 litColor = toonColor * (_MainLightColor * mainLightToonFactor + mainLightIntensityFactor.xxxx) +
        (_Brightness * mainLightIntensityFactor.xxxx); // Only apply diffuse here

    float3 additionalLightsColor = GetAdditionalLights(input, inputData, brdfData, shadowMask, meshRenderingLayers, aoFactor, inputData.viewDirectionWS);
    
    // return float4(specularHighlight.xyz, 1);

    float3 ambientLight = SampleSH(input.normalWS);
    if (_UseEmission > 0)
    {
        litColor += _EmissionColor.rgb * _EmissionIntensity;
    }
    litColor += (usePalette? 0 : toonColor) +  additionalLightsColor;
    if (!usePalette)
    {
        litColor += CalculateCellSpecular(brdfData, input, mainLight, inputData.viewDirectionWS, toonLevel);;
    }
    //+ ambientLight; // Apply final lit color to the texture or base color
    litColor *= _LightingColorTint + ambientLight;
    return float4(litColor.rgb, toonColor.a)/* + edgefactor*/;

    litColor += (usePalette? 0 : toonColor) +  additionalLightsColor;
    
    col.rgb *= litColor + (usePalette? 0 : CalculateCellSpecular(brdfData, input, mainLight, inputData.viewDirectionWS, toonLevel)) + additionalLightsColor;
    //+ ambientLight; // Apply final lit color to the texture or base color
    col.rgb *= _LightingColorTint + ambientLight;
    return col/* + edgefactor*/;
}
