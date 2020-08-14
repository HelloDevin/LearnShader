Shader "Wdx/ShaderBook/ForwardRendering"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Tags
        {
            //Opaque: 用于大多数着色器（法线着色器、自发光着色器、反射着色器以及地形的着色器）。
            //Transparent : 用于半透明着色器（透明着色器、粒子着色器、字体着色器、地形额外通道的着色器）。
            //TransparentCutout : 蒙皮透明着色器（Transparent Cutout，两个通道的植被着色器）。
            //Background : Skybox shaders.天空盒着色器。
            //Overlay : GUITexture, Halo, Flare shaders.光晕着色器、闪光着色器
            "RenderType" = "Opaque"
        }

        //Pass for ambient light & first pixel light (directional light)
        //该Pass处理了环境光、自发光、最重要的平行光（其他的平行光辉按照逐顶点或在Additional Pass中按逐像素的方式处理）
        Pass
        {
            Tags
            {
                //用于向前渲染，该Pass会计算环境光，最重要的平行光，逐顶点/SH光源和LightMaps
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            //确保我们在Shader中使用光照衰减等光照变量能被正确赋值
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(f.worldNormal);

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(f.worldPos));

                fixed3 halfDir = normalize(worldLightDir + worldViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

                //平行光没有衰减，为1.0
                fixed atten = 1.0;

                fixed3 color = ambient + (diffuse + specular) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        //Pass for other pixel lights
        Pass
        {
            Tags
            {
                //用于向前渲染，该模式代表除场景中最重要的平行光之外的额外光源的处理，每个光源会调用该pass一次
                "LightMode" = "ForwardAdd"
            }

            //混合模式，表示该Pass计算的光照结果可以在帧缓存中与之前的光照结果进行叠加，否则会覆盖之前的光照结果
            Blend One One

            CGPROGRAM
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                fixed3 worldNormal = normalize(f.worldNormal);
                
                //UnityWorldSpaceLightDir()已经做好光源判断
                //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
                //处理不同光源方向
                #ifdef USING_DIRECTIONAL_LIGHT
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - f.worldPos.xyz);
                #endif

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(f.worldPos));

                fixed3 halfDir = normalize(worldLightDir + worldViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

                //处理不同光源衰减
                #ifdef USING_DIRECTIONAL_LIGHT
                fixed atten = 1.0;
                #else
                #if defined (POINT)
                // 把点坐标转换到点光源的坐标空间中，unity_WorldToLight由引擎代码计算后传递到shader中，这里包含了对点光源范围的计算，具体可参考Unity引擎源码。经过unity_WorldToLight变换后，在点光源中心处lightCoord为(0, 0, 0)，在点光源的范围边缘处lightCoord为1
                float3 lightCoord = mul(unity_WorldToLight, float4(f.worldPos, 1)).xyz;
                // 使用点到光源中心距离的平方dot(lightCoord, lightCoord)构成二维采样坐标，对衰减纹理_LightTexture0采样。_LightTexture0纹理具体长什么样可以看后面的内容
                // UNITY_ATTEN_CHANNEL是衰减值所在的纹理通道，可以在内置的HLSLSupport.cginc文件中查看。一般PC和主机平台的话UNITY_ATTEN_CHANNEL是r通道，移动平台的话是a通道
                fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #elif defined (SPOT)
                // 把点坐标转换到聚光灯的坐标空间中，unity_WorldToLight由引擎代码计算后传递到shader中，这里面包含了对聚光灯的范围、角度的计算，具体可参考Unity引擎源码。经过unity_WorldToLight变换后，在聚光灯光源中心处或聚光灯范围外的lightCoord为(0, 0, 0)，在点光源的范围边缘处lightCoord模为1
                float4 lightCoord = mul(unity_WorldToLight, float4(f.worldPos, 1));
                // 与点光源不同，由于聚光灯有更多的角度等要求，因此为了得到衰减值，除了需要对衰减纹理采样外，还需要对聚光灯的范围、张角和方向进行判断
                // 此时衰减纹理存储到了_LightTextureB0中，这张纹理和点光源中的_LightTexture0是等价的
                // 聚光灯的_LightTexture0存储的不再是基于距离的衰减纹理，而是一张基于张角范围的衰减纹理
                // 最前面的(lightCoord.z > 0)是判断方向范围，因为聚光灯的张角范围小于180°，因此如果lightCoord.z <= 0的话它肯定不会被照亮，衰减值就直接是0
                fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                //聚光灯的光照衰减计算 https://www.zhihu.com/question/51060429/answer/123925972
                #else
                fixed atten = 1.0;
                #endif
                #endif

                fixed3 color = (diffuse + specular) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}