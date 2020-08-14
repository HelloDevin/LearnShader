Shader "Wdx/ShaderBook/MaskTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" { }
        _BumpMap("Normal Map",2D)="bump"{}
        _SpecularMask("Specular Mask",2D)="white"{}
        _SpecularScale("Specular Scale",Float)=1.0
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
            sampler2D _MainTex;//纹理名+ST 
            float4 _MainTex_ST;//xy存储缩放值 zw存储偏移值
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
                float4 texcoord : TEXCOORD0;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv:TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir:TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f f;

                f.pos = UnityObjectToClipPos(v.vertex);

                f.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

                //f.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                TANGENT_SPACE_ROTATION;

                f.lightDir=mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;

                f.viewDir=mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;

                return f;
            }

            fixed4 frag(v2f f) : SV_Target
            {

                fixed3 viewDir=normalize(f.viewDir);

                fixed3 lightDir=normalize(f.lightDir);

                fixed3 tangentNormal=UnpackNormal(tex2D(_BumpMap,f.uv));

                tangentNormal.xy*=_BumpScale;//缩放法线和副切线，以达到改变法线的方向

                tangentNormal=normalize(tangentNormal);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 albedo=tex2D(_MainTex,f.uv).rgb*_Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * albedo*saturate(dot(tangentNormal,lightDir));

                fixed3 halfDir = normalize(lightDir + viewDir);

                fixed3 specularMask=tex2D(_SpecularMask,f.uv).r*_Specular.rgb*_SpecularScale;

                fixed3 specular = _LightColor0.rgb * specularMask * pow(saturate(dot(tangentNormal,halfDir)), _Gloss);

                fixed3 color = ambient + diffuse + specular;

                return fixed4(color, 1);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}