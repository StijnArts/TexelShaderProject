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
    float3 lightDirection = normalize(light.direction);
    float3 normal = normalize(i.normalWS);
    viewDirection = normalize(viewDirection);
    float3 halfVector = normalize(lightDirection + viewDirection);
    
    // Compute specular term
    float NdotH = max(0.0, dot(normal, halfVector));
    float specularFactor = pow(NdotH, _HighlightSize);
    if (specularFactor < _HighlightSize) return 0;
    return light.color.rgb * _HighlightColor.rgb * light.shadowAttenuation * light.distanceAttenuation;
}

half3 SegmentedAdditionalLightsPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
    Light light,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatMask, bool specularHighlightsOff)
{
    half3 lightColor = light.color;
    half3 lightDirectionWS = light.direction;
    float lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    NdotL = floor(NdotL / _AdditionalLightSegmentation) *_AdditionalLightSegmentation;
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
    #ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

        #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

        half NoV = saturate(dot(normalWS, viewDirectionWS));
        half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
        #endif
    }
    #endif

    return brdf * radiance;
}

float3 GetAdditionalLights(InputData inputData, SurfaceData surfaceData, half4 shadowMask, AmbientOcclusionFactor aoFactor, BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 normalWS, half3 viewDirectionWS)
{
    uint meshRenderingLayers = GetMeshRenderingLayer();
    half3 additionalLightsColor = float3(0, 0, 0);
    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
            #endif
        {
            additionalLightsColor += SegmentedAdditionalLightsPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, !_DoHighlights);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        #endif
    {
        additionalLightsColor += SegmentedAdditionalLightsPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                      inputData.normalWS, inputData.viewDirectionWS,
                                                                      surfaceData.clearCoatMask, !_DoHighlights);
    }
    LIGHT_LOOP_END
    #endif
    return additionalLightsColor;
}

float4 GetBaseShadingColor(float NdotL, float2 uv)
{
    float firstTransition = smoothstep(_FirstShade - _FirstShadeTransitionSoftness,
                                                               _FirstShade + _FirstShadeTransitionSoftness,
                                                               NdotL);
    float secondTransition = smoothstep(_SecondShade - _SecondShadeTransitionSoftness,
                                                                _SecondShade +
                                                                _SecondShadeTransitionSoftness,
                                                                NdotL);
    float4 color = lerp(_SecondShadeColor, _FirstShadeColor, firstTransition);
    color = lerp(_ThirdShadeColor, color, secondTransition);

    return color;
}

float RandomFromSeed(float2 seed, float min, float max)
{
    float2 texelWorldSize = _BaseMap_TexelSize.xy;
    float2 snapped = floor(seed / texelWorldSize) * texelWorldSize;
    float randomno =  frac(sin(dot(snapped, float2(12.9898, 78.233)))*43758.5453);
    return lerp(min, max, randomno);
}

float4 GetPaletteBaseShadingColor(InputData inputData, Light mainLight, float toonLevel, float2 uv, half specular)
{
    float2 worldPos = inputData.positionWS.yz;

    // Define size of your "pixel grid" in world units

    // Snap world position to nearest grid cell

    // Feed snapped position into noise
    // float noise = RandomFromSeed(worldPos, 0, _TargetPaletteTex_TexelSize.y);

    // return float4(noise.xxx, 1);
            // return half4(noise.xxx, 1);
    
    // return half4(inputData.positionWS.xz, 1,1 );
    // if (toonLevel <= 0) return float4(1, 0.0f, 0.0f, 1);
    // else return float4(0, 1.0f, 0.0f, 1.0f);
    float4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    [loop]
    for (int i = 0; i < _TargetPaletteTex_TexelSize.z; i++)
    {
        if (i >= (int)_PaletteLength) return float4(0,1,0,1);
        // return float4(inputData.positionWS.xyz, 1);
        float texelWidth = _TargetPaletteTex_TexelSize.x;
        float u = (i + 0.5) * texelWidth;

        float4 srcCol = SAMPLE_TEXTURE2D(_PaletteTex, sampler_PaletteTex, float2(u, 0.5));
        if (all(abs(col.rgb - srcCol.rgb) < 0.001))
        {
            float lighting = saturate((toonLevel + 1.0+ _ColorOffset) * 0.5);
            // return lighting;
            float texelHeight = _TargetPaletteTex_TexelSize.y;
            // float normalizedLighting = saturate((lighting + 1.0) * 0.5); // [-1,1] -> [0,1]
            // float row = max(0.000001,lighting) / texelHeight;
            // float darkerRow = row+texelHeight;
            // float distanceToRow = abs(row - lighting);
            // return float4(row, 0,0,1);
            float totalRows = 1.0 / texelHeight;
            float rowFloat = lighting * (totalRows);
            float rowIndex = floor(rowFloat);
            float distanceToRowCenter = abs(rowFloat - (rowIndex));
            // return float4(distanceToRowCenter, 0,0,1);
            bool isOnShadeTransition = distanceToRowCenter < _DitherScale && toonLevel>0;
            // if (isOnShadeTransition) return float4(1,0,0,1);
            float noise = RandomFromSeed(inputData.positionWS.xz, 0, texelHeight);
            float addedNoise = 0;
            if (isOnShadeTransition && noise > _DitherStrength) addedNoise = -texelHeight;
            float4 color = SAMPLE_TEXTURE2D(_TargetPaletteTex, sampler_TargetPaletteTex, float2(u, lighting + addedNoise));
            float4 highlightColor = SAMPLE_TEXTURE2D(_TargetPaletteTex, sampler_TargetPaletteTex, float2(u, 1.0 - texelHeight * 0.5));
            float highlightStrength = smoothstep(0, 1.0, specular);
            if(toonLevel > 0) color.rgb += highlightColor.rgb *  mainLight.color * highlightStrength;
            color = saturate(color);

            return color;
        }
    }

    return col;
}

half4 GetFinalToonColor(Varyings input, InputData inputData, SurfaceData surfaceData, bool usePalette)
{
    BRDFData brdfData;
    
    InitializeBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
    float NdotL = dot(normalize(input.normalWS), normalize(mainLight.direction));
    float toonLevel = min(NdotL, mainLight.shadowAttenuation);
    
    float4 toonColor;
    if (usePalette) toonColor = GetPaletteBaseShadingColor(inputData, mainLight, toonLevel, input.uv,
        GetSpecularTerm(brdfData, input, mainLight, inputData.viewDirectionWS)*surfaceData.specular);
    else toonColor = GetBaseShadingColor(toonLevel, input.uv);
    return toonColor;
    float3 bdrfLighting = LightingPhysicallyBased(brdfData, mainLight, input.normalWS, inputData.viewDirectionWS);
    float3 litColor = toonColor + bdrfLighting + _Brightness * .2;
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    float3 additionalLightsColor = GetAdditionalLights(inputData, surfaceData, shadowMask, aoFactor, brdfData, brdfDataClearCoat, input.normalWS, inputData.viewDirectionWS);

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
    litColor *= _LightingColorTint  + ambientLight;
    return float4(litColor.rgb, toonColor.a);
    
}
