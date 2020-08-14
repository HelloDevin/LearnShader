Shader "Wdx/ShaderBook/SpecularFragment"
{
    Properties
    {
        _Diffuse ("Diffuse Color", Color) = (1, 1, 1, 1)
        _Specular ("Specular Color ", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment  frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : COLOR0;
                float3 worldPos : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f f;

                f.pos = UnityObjectToClipPos(v.vertex);

                f.worldNormal=UnityObjectToWorldNormal(v.normal);

                f.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;

                return f;
            }

            fixed4 frag(v2f f) : SV_Target
            {

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(f.worldNormal);

                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal, lightDir)*0.5+0.5);

                fixed3 reflectDir=normalize(reflect(-lightDir,worldNormal));

                fixed3 viewDir =normalize(_WorldSpaceCameraPos.xyz-f.worldPos);   

                fixed3 specular  =_LightColor0.rgb*_Specular.rgb*pow(saturate(dot(reflectDir,viewDir)),_Gloss);

                fixed3 color = ambient + diffuse+specular;

                return fixed4(color, 1);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}