package com.laporjalan.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class StaticResourceConfig implements WebMvcConfigurer {

    private final String uploadLocation;

    public StaticResourceConfig(@Value("${app.upload.directory:uploads}") String uploadDirectory) {
        Path path = Paths.get(uploadDirectory).toAbsolutePath().normalize();
        String pathUri = path.toUri().toString();
        uploadLocation = pathUri.endsWith("/") ? pathUri : pathUri + "/";
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadLocation);
    }
}
