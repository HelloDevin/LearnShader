using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

//[ExecuteInEditMode]
public class ShaderToyController : MonoBehaviour
{
    public Shader shaderToy;
    private Material shaderToyMaterial;

    public Material Material
    {
        get
        {
            shaderToyMaterial = GetMaterial(shaderToy,shaderToyMaterial);
            return shaderToyMaterial;
        }
    }

    public Material GetMaterial(Shader shader,Material material)
    {
        if (shader == null)
        {
            return null;
        }

        //如果Shader不被支持，则返回空
        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            //用此Shader创建临时材质，并返回
            material = new Material(shader)
            {
                hideFlags=HideFlags.DontSave
            };
            return material;
        }

    }

    /// <summary>
    /// 该函数允许我们使用着色器滤波操作来修改最终的图像，输入原图像source，输出的图像放在desitination里
    /// </summary>
    /// <param name="source"></param>
    /// <param name="destination"></param>
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //将原图的像素放置到destionation中
        Graphics.Blit(source, destination, Material);
    }
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnDisable()
    {
        if (shaderToyMaterial != null)
        {
            DestroyImmediate(shaderToyMaterial);
        }
    }

    private void OnGUI()
    {
        GUI.skin.button.fontSize = 30;
        if (GUILayout.Button("Test", GUILayout.Width(160), GUILayout.Height(50)))
        {
            //SceneManager.LoadScene("SampleScene2");
            Resources.UnloadUnusedAssets();
        }
    }
}
