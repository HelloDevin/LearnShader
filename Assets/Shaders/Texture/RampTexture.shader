Shader "Wdx/ShaderBook/RampTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _RampTex ("Ramp Tex", 2D) = "white" { }
        _Specular ("Specular Color ", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "LightingMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment  frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _RampTex;//纹理名+ST 
            float4 _RampTex_ST;//xy存储缩放值 zw存储偏移值
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f f;

                f.pos = UnityObjectToClipPos(v.vertex);

                //f.uv.xy = v.texcoord.xy * _RampTex_ST.xy + _RampTex_ST.zw;

                f.worldNormal=UnityObjectToWorldNormal(v.normal);

                f.worldPos=mul(unity_ObjectToWorld,v.vertex);

                f.uv=TRANSFORM_TEX(v.texcoord,_RampTex);

                return f;
            }

            fixed4 frag(v2f f) : SV_Target
            {

                fixed3 worldNormal=normalize(f.worldNormal);

                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(f.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed halfLambert=dot(worldNormal,worldLightDir)*0.5+0.5;

                fixed3 diffuseColor=tex2D(_RampTex,fixed2(halfLambert,halfLambert)).rgb*_Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * diffuseColor;

                fixed3 viewDir =normalize(UnityWorldSpaceViewDir(f.worldPos));              

                fixed3 halfDir = normalize(worldLightDir + viewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)), _Gloss);

                fixed3 color = ambient + diffuse + specular;

                return fixed4(color, 1);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}